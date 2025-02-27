WITH RecursivePostHierarchy AS (
    -- CTE to get hierarchy of posts (questions and answers)
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- All Questions

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        ph.Level + 1
    FROM Posts p
    JOIN RecursivePostHierarchy ph ON p.ParentId = ph.PostId
    WHERE p.PostTypeId = 2  -- Only Answers
),
PostVoteCounts AS (
    -- CTE to count votes for each post
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    GROUP BY v.PostId
),
PostWithVoteInfo AS (
    -- Combine posts with their vote counts and filtering out deleted users
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        ph.Level,
        COALESCE(pvc.Upvotes, 0) AS Upvotes,
        COALESCE(pvc.Downvotes, 0) AS Downvotes,
        p.CreationDate,
        p.Title
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
    LEFT JOIN RecursivePostHierarchy rph ON p.Id = rph.PostId
    WHERE p.OwnerUserId IS NOT NULL -- Exclude deleted users
    GROUP BY p.Id, pvc.Upvotes, pvc.Downvotes, ph.Level
),
RankedPosts AS (
    -- Ranking posts by upvotes while considering comment counts
    SELECT
        PostId,
        Title,
        Upvotes,
        Downvotes,
        CommentCount,
        CreationDate,
        RANK() OVER (ORDER BY Upvotes - Downvotes DESC, CommentCount DESC) AS Rank
    FROM PostWithVoteInfo
)
-- Final selection of posts showing their ranking, upvotes, downvotes, and other info
SELECT
    rp.PostId,
    rp.Title,
    rp.Upvotes,
    rp.Downvotes,
    rp.CommentCount,
    rp.Rank,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Question'
        ELSE 'Other'
    END AS PostCategory
FROM RankedPosts rp
WHERE rp.Rank <= 50  -- Get top 50 ranked posts
ORDER BY rp.Rank;
