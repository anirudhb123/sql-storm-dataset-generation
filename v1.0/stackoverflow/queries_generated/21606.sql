WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM Posts AS p2 WHERE p2.ParentId = p.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureChangeCount
    FROM PostHistory ph
    WHERE ph.CreationDate < NOW() -- Limit to historic data
    GROUP BY ph.PostId
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        COALESCE(ph.LastClosedDate, 'N/A') AS LastClosedDate,
        COALESCE(pb.AnswerCount, 0) AS AnswerCount,
        COALESCE(pb.CommentCount, 0) AS CommentCount,
        COALESCE(pb.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(pb.DownVoteCount, 0) AS DownVoteCount,
        ub.BadgeCount,
        ub.GoldCount,
        ub.SilverCount,
        ub.BronzeCount
    FROM Posts p
    LEFT JOIN PostActivity pb ON p.Id = pb.PostId
    LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
    LEFT JOIN UserBadgeCounts ub ON p.OwnerUserId = ub.UserId
    WHERE p.Draft IS NULL  -- Exclude drafts or similar logic (assumed here for the schema)
      AND (p.LastActivityDate > NOW() - INTERVAL '1 year' OR ph.ClosureChangeCount > 0)  -- Active or modified posts
)
SELECT 
    ap.Title,
    ap.LastActivityDate,
    ap.LastClosedDate,
    ap.AnswerCount,
    ap.CommentCount,
    ap.UpVoteCount,
    ap.DownVoteCount,
    ap.BadgeCount,
    ap.GoldCount,
    ap.SilverCount,
    ap.BronzeCount,
    CASE 
        WHEN ap.LastClosedDate IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus,
    COALESCE(NULLIF(ap.CommentCount, 0), NULLIF(ap.UpVoteCount, 0), 0) AS ActivityIndicator
FROM ActivePosts ap
WHERE (ap.BadgeCount > 10 OR ap.LastActivityDate IS NOT NULL)
ORDER BY 
    ap.LastActivityDate DESC,
    ap.BadgeCount DESC
LIMIT 100;
