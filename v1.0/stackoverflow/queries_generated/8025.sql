WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
AggregateScores AS (
    SELECT 
        PostId,
        SUM(Score) AS TotalScore,
        COUNT(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        p.PostId,
        p.Title,
        p.OwnerDisplayName,
        a.TotalScore,
        a.TotalComments,
        CASE 
            WHEN p.Rank <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS RankCategory
    FROM 
        RankedPosts p
    JOIN 
        AggregateScores a ON p.PostId = a.PostId
)
SELECT 
    RankCategory,
    COUNT(PostId) AS PostCount,
    AVG(TotalScore) AS AverageScore,
    SUM(TotalComments) AS TotalComments
FROM 
    PostDetails
GROUP BY 
    RankCategory
ORDER BY 
    RankCategory DESC;
