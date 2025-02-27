WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(vote.VoteTypeId = 2) AS UpVoteCount,
        SUM(vote.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
PostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        SUM(CASE WHEN h.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
        COUNT(DISTINCT h.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, p.Title
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.Score,
    COALESCE(pr.CommentCount, 0) AS CommentCount,
    COALESCE(pa.CloseOpenCount, 0) AS CloseOpenCount,
    COALESCE(pa.EditCount, 0) AS EditCount,
    COALESCE(ur.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN pr.UpVoteCount IS NULL THEN 0
        WHEN pr.UpVoteCount > pr.DownVoteCount THEN 'Positive'
        WHEN pr.UpVoteCount < pr.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN (SELECT COUNT(*) FROM Posts WHERE ViewCount IS NULL) > 0 THEN 'Some posts have no views'
        ELSE 'All posts have views'
    END AS ViewStatus
FROM 
    RankedPosts pr
LEFT JOIN 
    PostActivity pa ON pr.PostId = pa.Id
LEFT JOIN 
    Users u ON pr.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    pr.Rank = 1
    AND pr.ViewCount IS NOT NULL 
    AND (pr.Score > 10 OR pr.Title LIKE '%SQL%')
ORDER BY 
    pr.Score DESC, 
    pr.CreationDate ASC
LIMIT 1000;
