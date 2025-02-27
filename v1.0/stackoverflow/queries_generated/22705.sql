WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,  -- Only count upvotes
        SUM(v.VoteTypeId = 3) AS Downvotes, -- Only count downvotes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  -- Questions and Answers only
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostClosure AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosureDate,
        crt.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN pc.ClosureDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        au.DisplayName AS TopUser,
        au.Reputation AS UserReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostClosure pc ON rp.PostId = pc.PostId AND pc.ClosureRank = 1
    LEFT JOIN 
        ActiveUsers au ON rp.PostRank = 1 AND rp.Upvotes > 0  -- Rank 1 user who has at least one upvote
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.PostStatus,
    ps.TopUser,
    ps.UserReputation,
    COALESCE(ps.Upvotes - ps.Downvotes, 0) AS NetVotes,
    CASE 
        WHEN ps.CommentCount > 10 THEN 'Highly Commented'
        WHEN ps.CommentCount BETWEEN 1 AND 10 THEN 'Moderately Commented'
        ELSE 'No Comments'
    END AS CommentQuality
FROM 
    PostSummary ps
WHERE 
    ps.PostStatus = 'Active'
ORDER BY 
    ps.Upvotes DESC, 
    ps.CommentCount DESC;

This query captures an elaborate set of metrics related to posts, users, and closures. It uses CTEs for organization and hierarchical ranking, integrates conditional logic for determining post status, and aggregates user reputation with respect to their activity. Additionally, it includes advanced window functions, conditional ranking, and unusual assessments of comment quality while taking care of NULL logic with `COALESCE`.
