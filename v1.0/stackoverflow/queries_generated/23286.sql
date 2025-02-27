WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        U.DisplayName AS Author,
        p.CreationDate,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Users U ON p.OwnerUserId = U.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, U.DisplayName, p.CreationDate, p.Title
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(*) AS BadgeCount
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '2 years'
    GROUP BY b.UserId
),
PostLinkSummary AS (
    SELECT 
        pl.PostId,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT lt.Name) AS LinkTypeList
    FROM PostLinks pl
    LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.CommentCount,
    COALESCE(bs.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bs.BadgeList, 'No Badges') AS UserBadges,
    ps.RelatedPostCount,
    ps.LinkTypeList,
    CASE 
        WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive Engagement'
        WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType,
    CASE 
        WHEN (rp.UpVoteCount + rp.DownVoteCount) = 0 THEN 'No Votes Yet'
        ELSE CONCAT((rp.UpVoteCount - rp.DownVoteCount), ' Vote Balance')
    END AS VoteBalance,
    CASE 
        WHEN rp.RN = 1 THEN 'Most Recent Post'
        ELSE 'Older Post'
    END AS RecencyIndicator
FROM RankedPosts rp
LEFT JOIN BadgeSummary bs ON rp.Author = (SELECT U.DisplayName FROM Users U WHERE U.Id = bs.UserId)
LEFT JOIN PostLinkSummary ps ON rp.PostId = ps.PostId
WHERE (rp.CommentCount > 5 OR rp.UpVoteCount > 10 OR ps.RelatedPostCount > 0)
ORDER BY rp.CreationDate DESC
LIMIT 50 OFFSET 0;
