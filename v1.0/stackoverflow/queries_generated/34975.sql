WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.Id = rph.ParentId
),
PostVoteStatistics AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
RecentComments AS (
    SELECT 
        c.PostId, 
        c.Text, 
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS rn
    FROM 
        Comments c
),
CombinedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        COALESCE(rc.Text, '') AS RecentComment,
        r.Depth AS PostDepth,
        DATEDIFF(second, p.CreationDate, CURRENT_TIMESTAMP) AS AgeInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStatistics rv ON p.Id = rv.PostId
    LEFT JOIN 
        RecentComments rc ON p.Id = rc.PostId AND rc.rn = 1
    JOIN 
        RecursivePostHierarchy r ON p.Id = r.PostId
)
SELECT 
    PostId,
    Title,
    Score,
    UpVotes,
    DownVotes,
    RecentComment,
    PostDepth,
    AgeInSeconds,
    CASE 
        WHEN AgeInSeconds > 86400 THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory
FROM 
    CombinedPostData
WHERE 
    PostDepth < 3  -- Only show top-level and first-level responses
ORDER BY 
    Score DESC, 
    AgeInSeconds ASC;
