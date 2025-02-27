WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
), PostAnalytics AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments,
        SUM(p.VoteCount) AS TotalVotes,
        COUNT(p.PostId) AS PostCount
    FROM 
        RankedPosts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(pa.TotalViews, 0) AS TotalViews,
    COALESCE(pa.TotalComments, 0) AS TotalComments,
    COALESCE(pa.TotalVotes, 0) AS TotalVotes,
    COALESCE(pa.PostCount, 0) AS PostCount,
    CASE 
        WHEN COALESCE(pa.PostCount, 0) > 0 THEN ROUND(COALESCE(pa.TotalVotes, 0) * 100.0 / COALESCE(pa.PostCount, 1), 2)
        ELSE 0
    END AS AverageVotesPerPost
FROM 
    Users u
LEFT JOIN 
    PostAnalytics pa ON u.Id = pa.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    TotalVotes DESC, TotalViews DESC;
