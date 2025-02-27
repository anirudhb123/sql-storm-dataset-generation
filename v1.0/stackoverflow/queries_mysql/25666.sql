
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@current_tag = p.Tags, @row_number + 1, 1) AS Rank,
        @current_tag := p.Tags,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    CROSS JOIN (SELECT @row_number := 0, @current_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Rank,
        rp.CommentCount,
        rp.AverageBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
)
SELECT 
    tp.Tags,
    GROUP_CONCAT(DISTINCT tp.Title) AS TopPostTitles,
    COUNT(tp.PostId) AS TotalTopPosts,
    SUM(tp.CommentCount) AS TotalComments,
    AVG(tp.AverageBounty) AS OverallAverageBounty
FROM 
    TopPosts tp
GROUP BY 
    tp.Tags
ORDER BY 
    TotalTopPosts DESC;
