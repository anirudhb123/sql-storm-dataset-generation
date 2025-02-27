WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start from questions
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
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(ph.UserId IS NOT NULL, 0)::int) AS TotalPostHistory
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    u.DisplayName AS Owner,
    ps.UpVotes,
    ps.DownVotes,
    u.TotalPosts,
    u.TotalPostHistory,
    r.Level,
    DATE_PART('day', CURRENT_TIMESTAMP - r.CreationDate) AS DaysSinceCreation
FROM 
    RecursivePostHierarchy r
JOIN 
    PostVoteSummary ps ON r.PostId = ps.PostId
JOIN 
    Users u ON r.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    r.Level > 1  -- Show only answers
    AND ps.TotalVotes > 0
ORDER BY 
    DaysSinceCreation DESC,
    ps.UpVotes DESC
LIMIT 100;

WITH TagsCTE AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        Tags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) >= 10
),
TopTags AS (
    SELECT 
        TagName,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagsCTE
)
SELECT 
    t.TagName,
    t.PostCount,
    COALESCE(STRING_AGG(DISTINCT p.Title, ', '), 'No Posts Yet') AS RelatedPostTitles
FROM 
    TagsCTE t
LEFT JOIN 
    Posts p ON POSITION(t.TagName IN p.Tags) > 0
GROUP BY 
    t.TagName, t.PostCount
ORDER BY 
    t.PostCount DESC;
