WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.Score + rp.UpVoteCount - rp.DownVoteCount > 10 THEN 'Highly Active'
            WHEN rp.Score + rp.UpVoteCount - rp.DownVoteCount BETWEEN 1 AND 10 THEN 'Moderately Active'
            ELSE 'Low Activity'
        END AS ActivityLevel,
        CASE
            WHEN rp.CommentCount = 0 THEN 'No Comments'
            ELSE 'Has Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1 -- Focus on the latest post by each user
),
FinalStats AS (
    SELECT 
        ps.*,
        pt.Name AS PostType,
        ut.DisplayName AS OwnerDisplayName,
        bt.Name AS BadgeName,
        CASE 
            WHEN bt.Id IS NOT NULL THEN 'Has Badge' 
            ELSE 'No Badge' 
        END AS BadgeStatus
    FROM 
        PostStats ps
    LEFT JOIN 
        Users ut ON ut.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    LEFT JOIN 
        Badges bt ON bt.UserId = ut.Id AND bt.Date >= ps.CreationDate -- Badges acquired after post creation
),
FilteredStats AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ActivityLevel ORDER BY CreationDate DESC) AS ActivityRank
    FROM 
        FinalStats
    WHERE 
        ActivityLevel <> 'Low Activity'
)
SELECT 
    *
FROM 
    FilteredStats
WHERE 
    ActivityRank <= 5 -- Top 5 from each activity level
ORDER BY 
    ActivityLevel, CreationDate DESC;

-- This query is intended to benchmark the performance implications of employing various SQL constructs including CTEs, window functions, and multiple joins.

