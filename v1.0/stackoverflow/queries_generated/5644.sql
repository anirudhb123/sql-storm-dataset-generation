WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        AnswerCount, 
        ViewCount, 
        CreationDate, 
        UserDisplayName 
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViews,
        SUM(Score) AS TotalScore
    FROM 
        TopPosts tp
    JOIN 
        Posts p ON tp.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    ps.PostTypeName,
    ps.TotalPosts,
    ps.AverageViews,
    ps.TotalScore,
    COUNT(b.Id) AS BadgeCount
FROM 
    PostStatistics ps
LEFT JOIN 
    Badges b ON b.UserId IN (SELECT DISTINCT OwnerUserId FROM TopPosts)
GROUP BY 
    ps.PostTypeName, ps.TotalPosts, ps.AverageViews, ps.TotalScore
ORDER BY 
    ps.TotalScore DESC;
