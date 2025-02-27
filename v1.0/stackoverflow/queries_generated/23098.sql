WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, u.Reputation
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- only title, body, and tags edits
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN pp.PostId IS NOT NULL THEN 1 ELSE 0 END) AS PostsWithAcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts pp ON u.Id = pp.OwnerUserId AND pp.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        u.Id
),
NullHandling AS (
    SELECT 
        COALESCE(MAX(rp.CommentCount), 0) AS MaxCommentCount,
        COUNT(DISTINCT u.Id) AS UserCount
    FROM 
        RankedPosts rp
    FULL OUTER JOIN 
        Users u ON rp.OwnerDisplayName IS NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    re.EditDate,
    re.UserDisplayName AS LastEditedBy,
    u.BadgeCount,
    u.PostsWithAcceptedAnswers,
    nh.MaxCommentCount,
    nh.UserCount,
    CASE 
        WHEN rp.CommentCount > nh.MaxCommentCount THEN 'Above Average'
        ELSE 'Below Average'
    END AS CommentPerformance,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) THEN 'Has Downvotes'
        ELSE 'No Downvotes'
    END AS DownvoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
LEFT JOIN 
    ActiveUsers u ON rp.OwnerDisplayName = u.UserId
CROSS JOIN 
    NullHandling nh
WHERE 
    rp.rn <= 10  -- Limit to the latest 10 posts by type
ORDER BY 
    rp.CreationDate DESC;
