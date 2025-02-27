WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting point for top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
JoinedData AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryUpdate
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, v.UpVotes, v.DownVotes
),
FilteredPosts AS (
    SELECT 
        j.*,
        CASE 
            WHEN j.UpVotes > j.DownVotes THEN 'More Upvotes'
            WHEN j.DownVotes > j.UpVotes THEN 'More Downvotes'
            ELSE 'Equal Votes'
        END AS VoteStatus,
        ROW_NUMBER() OVER (ORDER BY j.ViewCount DESC) AS Rank
    FROM 
        JoinedData j
    WHERE 
        j.ViewCount > 100  -- Filtering posts with more than 100 views
)

SELECT 
    f.Id,
    f.Title,
    f.ViewCount,
    f.UpVotes,
    f.DownVotes,
    f.CommentCount,
    f.LastHistoryUpdate,
    f.VoteStatus,
    r.Level AS HierarchyLevel
FROM 
    FilteredPosts f
LEFT JOIN 
    RecursivePostHierarchy r ON f.Id = r.Id
WHERE 
    r.Level IS NULL OR r.Level <= 3  -- Considering hierarchy level up to 3
ORDER BY 
    f.Rank, f.LastHistoryUpdate DESC;  -- Ordering by Rank first, then by Last update
This query creates a recursive common table expression (CTE) to represent post hierarchies, computes aggregate vote counts and associated data via joins, selects filtered posts, and determines their vote status, while also efficiently organizing and presenting data from multiple aspects of the schema.
