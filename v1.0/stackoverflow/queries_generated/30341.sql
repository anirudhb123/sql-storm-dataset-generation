WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
),

PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),

TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5 -- Only tags used in more than 5 posts
),

PostHistoryData AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS FirstClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Deleted' THEN ph.CreationDate END) AS LastDeletedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    ph.PostId,
    ph.Title,
    pvs.UpVotes,
    pvs.DownVotes,
    COALESCE(phd.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    COALESCE(phd.LastDeletedDate, 'Not Deleted') AS LastDeletedDate,
    CASE 
        WHEN r.Level IS NULL THEN 0
        ELSE r.Level
    END AS AnswerLevel,
    tt.TagName
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    PostVoteSummary pvs ON r.PostId = pvs.PostId
LEFT JOIN 
    PostHistoryData phd ON r.PostId = phd.PostId
CROSS JOIN 
    (SELECT DISTINCT TagName FROM TopTags) tt
WHERE 
    r.PostId IN (SELECT p.Id FROM Posts p WHERE p.ViewCount > 100)
ORDER BY 
    r.Level DESC, 
    pvs.UpVotes DESC;
