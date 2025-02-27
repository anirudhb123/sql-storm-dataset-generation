WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        MAX(v.CreationDate) AS LatestVoteDate
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.PostTypeId
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROUND(AVG(u.Reputation), 2) AS AverageReputation
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
FilteredPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        pl.LinkTypeId,
        CASE 
            WHEN pl.LinkTypeId = 3 THEN 'Duplicate'
            ELSE 'Linked'
        END AS LinkStatus
    FROM 
        PostLinks pl
    WHERE 
        pl.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT 
    p.Id AS PostId,
    p.Title,
    r.ViewCount AS Popularity,
    r.ViewRank,
    u.UserId,
    u.BadgeCount,
    u.UpvoteCount,
    u.DownvoteCount,
    (u.UpvoteCount - u.DownvoteCount) AS NetVotes,
    COALESCE(link.RelatedPostId, -1) AS LinkPostId,
    link.LinkStatus
FROM 
    RankedPosts r
JOIN 
    UserStatistics u ON u.UserId = r.Id
LEFT JOIN 
    FilteredPostLinks link ON link.PostId = r.Id
WHERE 
    r.ViewRank <= 5
    AND u.AverageReputation > 100
    AND (EXTRACT(DOW FROM r.CreationDate) IN (0, 6) OR u.BadgeCount > 2)
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 50;
