WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.PostTypeId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Base case: top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.PostTypeId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Users with post activity in the last year
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5  -- Only consider users with more than 5 posts
    ORDER BY 
        TotalViews DESC
    LIMIT 10  -- Top 10 users
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    pvs.UpVotes,
    pvs.DownVotes,
    (pvs.UpVotes - pvs.DownVotes) AS VoteNet,
    pu.DisplayName AS PopularUser,
    pu.TotalViews
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteSummary pvs ON ph.PostId = pvs.PostId
LEFT JOIN 
    PopularUsers pu ON pu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId LIMIT 1)  -- Get the first user related to that post
WHERE 
    ph.PostTypeId = 1  -- Only questions
ORDER BY 
    VoteNet DESC, 
    TotalViews DESC NULLS LAST  -- Sorting by net votes and then views, with NULLs in views last
LIMIT 20;  -- Limit the final output to the top 20 results
