WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.Score > 0 -- Only Questions with positive score
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes crt ON crt.Id = JSON_VALUE(ph.Comment, '$.CloseReasonId')
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.Comment
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostEngagement AS (
    SELECT 
        p.Id,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    rcr.CloseReason,
    ub.BadgeNames,
    pe.CommentCount,
    pe.UpVoteCount,
    pe.DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentCloseReasons rcr ON rp.PostId = rcr.PostId 
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (SELECT DISTINCT PostId FROM Posts WHERE OwnerUserId = ub.UserId)
LEFT JOIN 
    PostEngagement pe ON rp.PostId = pe.Id
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC;
