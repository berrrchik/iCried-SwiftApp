import SwiftUI
import SwiftData

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for (index, row) in rows.enumerated() {
            var rowWidth: CGFloat = 0
            let rowHeight = row.first?.sizeThatFits(.unspecified).height ?? 0
            
            for (viewIndex, view) in row.enumerated() {
                let viewDimensions = view.sizeThatFits(.unspecified)
                rowWidth += viewDimensions.width
                if viewIndex < row.count - 1 {
                    rowWidth += spacing
                }
            }
            
            totalWidth = max(totalWidth, rowWidth)
            totalHeight += rowHeight
            if index < rows.count - 1 {
                totalHeight += spacing
            }
        }
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            
            for index in row.indices {
                let view = row[index]
                let viewSize = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
                x += viewSize.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRow = 0
        var x: CGFloat = 0
        
        for view in subviews {
            let viewDimensions = view.sizeThatFits(.unspecified)
            let width = viewDimensions.width
            
            if x + width > (proposal.width ?? .infinity) {
                currentRow += 1
                rows.append([])
                x = width + spacing
            } else {
                x += width + spacing
            }
            
            rows[currentRow].append(view)
        }
        
        return rows
    }
}
