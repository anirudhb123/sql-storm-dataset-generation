WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- Bounty Start
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id, u.DisplayName
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
        rp.Rank <= 5 -- Top 5 posts per tag
)
SELECT 
    tp.Tags,
    ARRAY_AGG(DISTINCT tp.Title) AS TopPostTitles,
    COUNT(tp.PostId) AS TotalTopPosts,
    SUM(tp.CommentCount) AS TotalComments,
    AVG(tp.AverageBounty) AS OverallAverageBounty
FROM 
    TopPosts tp
GROUP BY 
    tp.Tags
ORDER BY 
    TotalTopPosts DESC;

This query effectively benchmarks string processing by analyzing and ranking the top questions from the `Posts` table, leveraging string manipulation through `Tags`, while aggregating relevant information such as comment counts and bounties to provide insights into engagement and quality per tag.
