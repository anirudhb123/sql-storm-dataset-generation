
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),
AggregatedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pt.Name AS PostHistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
),
FilteredVotes AS (
    SELECT 
        v.PostId, 
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),
TopUsers AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        UserId 
)

SELECT TOP 50
    a.UserId,
    a.DisplayName,
    a.PostCount,
    a.TotalScore,
    COALESCE(sp.ClosedPostsCount, 0) AS ClosedPostsCount,
    COALESCE(tv.TotalVotes, 0) AS TotalVotes
FROM 
    AggregatedStats a
LEFT JOIN (
    SELECT 
        c.UserId, 
        COUNT(c.PostId) AS ClosedPostsCount
    FROM 
        ClosedPostDetails c
    GROUP BY 
        c.UserId
) sp ON a.UserId = sp.UserId
LEFT JOIN (
    SELECT 
        tu.UserId, 
        SUM(fv.VoteCount) AS TotalVotes
    FROM 
        TopUsers tu
    JOIN 
        FilteredVotes fv ON tu.UserId = fv.PostId
    GROUP BY 
        tu.UserId
) tv ON a.UserId = tv.UserId
WHERE 
    a.TotalScore > 0
ORDER BY 
    a.TotalScore DESC,
    a.PostCount DESC;
