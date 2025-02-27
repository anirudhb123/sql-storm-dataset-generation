WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        pl.LinkTypeId, 
        1 AS LinkDepth
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 3  -- Only considering duplicates

    UNION ALL

    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        pl.LinkTypeId, 
        rpl.LinkDepth + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostLinks rpl ON pl.RelatedPostId = rpl.PostId
    WHERE 
        pl.LinkTypeId = 3 AND rpl.LinkDepth < 5  -- Limit depth to avoid infinite recursion
),
UserBadges AS (
    SELECT 
        u.Id as UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount, 
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(NULLIF(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0), NULL) AS NetScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
PostAnalysis AS (
    SELECT 
        p.Title, 
        p.CreationDate,
        u.BadgeCount, 
        u.HighestBadgeClass,
        rps.CommentCount,
        rps.UpVoteCount,
        rps.DownVoteCount,
        rps.NetScore,
        CASE 
            WHEN rps.NetScore > 0 THEN 'Positive'
            WHEN rps.NetScore < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        RecentPostStats rps
    JOIN 
        Users u ON rps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN 
        RecursivePostLinks rpl ON rpl.PostId = rps.PostId
    WHERE 
        u.BadgeCount > 0 
)
SELECT 
    pa.Title,
    pa.CreationDate,
    pa.BadgeCount,
    pa.HighestBadgeClass,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.NetScore,
    pa.PostSentiment,
    COUNT(DISTINCT rpl.RelatedPostId) AS DuplicateCount
FROM 
    PostAnalysis pa
LEFT JOIN 
    RecursivePostLinks rpl ON pa.PostId = rpl.PostId
GROUP BY 
    pa.Title, pa.CreationDate, pa.BadgeCount, pa.HighestBadgeClass, 
    pa.CommentCount, pa.UpVoteCount, pa.DownVoteCount, pa.NetScore, 
    pa.PostSentiment
ORDER BY 
    pa.NetScore DESC, 
    pa.CreationDate DESC;
