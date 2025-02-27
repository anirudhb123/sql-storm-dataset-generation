WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        r.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostWithVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
        COALESCE(uv.TotalVotes, 0) AS OverallVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        UserVotes uv ON p.OwnerUserId = uv.UserId
),
RecentActivity AS (
    SELECT 
        PostId,
        MAX(CreationDate) AS LastActivityDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        p.Title,
        ph.PostId,
        ph.Level,
        p.Score,
        r.LastActivityDate,
        p.TotalUpVotes,
        p.TotalDownVotes,
        CASE 
            WHEN ph.Level > 1 THEN 'Nested'
            ELSE 'Root'
        END AS HierarchyType
    FROM 
        RecursivePostHierarchy ph
    JOIN 
        PostWithVoteCounts p ON ph.PostId = p.PostId
    LEFT JOIN 
        RecentActivity r ON p.PostId = r.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.HierarchyType,
    pd.LastActivityDate,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tags ON t.TagName = tags) AS TagList
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.LastActivityDate DESC;
