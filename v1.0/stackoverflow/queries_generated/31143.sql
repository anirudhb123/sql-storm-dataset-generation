WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
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
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostAge AS (
    SELECT 
        Id,
        DATEDIFF(CURRENT_TIMESTAMP, CreationDate) AS AgeInDays
    FROM 
        Posts
),
PopularVotes AS (
    SELECT 
        p.Title,
        p.Id,
        p.AgeInDays,
        COALESCE(ps.UpVotes, 0) AS UpVotes,
        COALESCE(ps.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(ps.UpVotes - ps.DownVotes, 0) DESC) AS VoteRank
    FROM 
        PostAge p
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
),
TopQuestions AS (
    SELECT 
        p.*,
        CASE 
            WHEN Votes.UpVotes > 0 THEN 'Active' 
            ELSE 'Inactive' 
        END AS ActivityStatus
    FROM 
        Posts p
    JOIN 
        PopularVotes pv ON p.Id = pv.Id
    WHERE 
        p.PostTypeId = 1  -- Questions only
        AND pv.VoteRank <= 10  -- Limit to top 10
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.ActivityStatus,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
               FROM Tags t 
               WHERE t.Id IN (SELECT UNNEST(string_to_array(tq.Tags, ','))::int)), '') , 'No Tags') AS TagList,
    CASE 
        WHEN rq.PostId IS NOT NULL THEN 'This question has accepted answer.'
        ELSE 'This question has NO accepted answer.'
    END AS AcceptedAnswerStatus
FROM 
    TopQuestions tq
LEFT JOIN 
    RecursivePostHierarchy rq ON tq.AcceptedAnswerId = rq.PostId
ORDER BY 
    tq.CreationDate DESC;
