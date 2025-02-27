WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON tag_name IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteDetails AS (
    SELECT 
        postId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        postId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(cp.ClosedDate, 'Not Closed') AS PostStatus,
    COALESCE(cp.CloseReason, 'N/A') AS CloseDetails,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    u.BadgeCount,
    u.HighestBadgeClass,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges u ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostVoteDetails v ON rp.PostId = v.postId
WHERE 
    (rp.PostRank <= 5 OR rp.Score > 100) -- Obscure predicate for filtering
ORDER BY 
    rp.CreationDate DESC NULLS LAST; -- Ordering with unusual NULL logic

