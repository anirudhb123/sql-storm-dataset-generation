WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -5, GETDATE()) AND 
        p.ViewCount IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 3
), 
MostActiveUsers AS (
    SELECT 
        UserId, 
        TotalBadges, 
        PostCount,
        RANK() OVER (ORDER BY TotalBadges DESC) AS UserRank
    FROM 
        TopUsers
)
SELECT 
    pu.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    mu.UserRank,
    CASE 
        WHEN (mu.TotalBadges > 0) THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        ELSE 'Has Views'
    END AS ViewStatus 
FROM 
    MostActiveUsers mu
JOIN 
    RankedPosts rp ON mu.UserId = rp.OwnerUserId
JOIN 
    Users pu ON mu.UserId = pu.Id 
WHERE 
    mu.UserRank <= 5 
    AND rp.Rank = 1 
ORDER BY 
    mu.UserRank, 
    rp.ViewCount DESC;

WITH CommentsStatistics AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN COALESCE(c.CommentCount, 0) > 10 THEN 'Highly Discussed'
        WHEN COALESCE(v.UpVotes, 0) > COALESCE(v.DownVotes, 0) THEN 'Positive' 
        ELSE 'Needs Attention' 
    END AS PostSentiment
FROM 
    Posts p
LEFT JOIN 
    CommentsStatistics c ON p.Id = c.PostId
LEFT JOIN 
    VoteStatistics v ON p.Id = v.PostId
WHERE 
    p.CreationDate < DATEADD(YEAR, -2, GETDATE()
    AND p.OwnerUserId IS NOT NULL
ORDER BY 
    PostSentiment, 
    c.CommentCount DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
