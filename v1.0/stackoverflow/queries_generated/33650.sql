WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find the hierarchy of posts (questions and their answers)
    SELECT 
        Id,
        Title,
        ParentId,
        OwnerUserId,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start from root questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),

UserVoteStats AS (
    -- CTE to calculate vote statistics per user
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryAnalysis AS (
    -- CTE analyzing post history types and counts
    SELECT 
        ph.PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletedCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.PostId, p.Title, p.OwnerUserId
),

FinalBenchmark AS (
    -- Final selection combining all analytical layers
    SELECT 
        rph.Id AS PostId,
        rph.Title AS QuestionTitle,
        rph.CreationDate AS QuestionCreationDate,
        uvs.DisplayName AS UserName,
        uvs.Upvotes,
        uvs.Downvotes,
        phl.ClosedCount,
        phl.DeletedCount,
        phl.LastModified,
        RANK() OVER (PARTITION BY rph.OwnerUserId ORDER BY rph.CreationDate DESC) AS RankByActivity
    FROM 
        RecursivePostHierarchy rph
    JOIN 
        UserVoteStats uvs ON rph.OwnerUserId = uvs.UserId
    JOIN 
        PostHistoryAnalysis phl ON rph.Id = phl.PostId
)

SELECT 
    *,
    CASE 
        WHEN ClosedCount > 0 THEN 'Closed'
        WHEN DeletedCount > 0 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FinalBenchmark
WHERE 
    (Upvotes - Downvotes) > 5  -- Filter for posts with a net positive score
ORDER BY 
    RankByActivity, QuestionCreationDate DESC;

