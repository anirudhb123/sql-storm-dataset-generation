WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= '2023-01-01' -- Questions created this year
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostTagStats AS (
    SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(p.Id) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    COALESCE(ua.EditCount, 0) AS UserEditCount,
    COALESCE(ua.VoteCount, 0) AS UserVoteCount,
    COALESCE(uba.BadgeCount, 0) AS BadgeCount,
    COALESCE(uba.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(ps.Tags, 'No Tags') AS PostTags,
    COALESCE(cd.ClosedDate, 'Open') AS PostClosedDate,
    COALESCE(cd.CloseReason, 'N/A') AS CloseReason,
    (u.Reputation + 10 * COALESCE(ua.UpVotes - ua.DownVotes, 0)) AS AdjustedReputation,
    CASE 
        WHEN rp.Score > 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.PostID = ua.UserId
LEFT JOIN 
    UserWithBadges uba ON ua.UserId = uba.UserId
LEFT JOIN 
    PostTagStats ps ON rp.PostID = ps.TagCount
LEFT JOIN 
    ClosedPostDetails cd ON rp.PostID = cd.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.Rank = 1 -- Only the latest question for each user
ORDER BY 
    rp.CreationDate DESC, AdjustedReputation DESC
LIMIT 100;
