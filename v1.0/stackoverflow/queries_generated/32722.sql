WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ParentId, 
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ParentId, 
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(p.Score, 0)) AS PostScore,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteStats v ON p.Id = v.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) > 0
),
TopTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    ph.PostId, 
    ph.Title, 
    ph.Level,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    u.DisplayName AS TopUser,
    t.TagName AS TopTag
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostVoteStats vs ON ph.PostId = vs.PostId
LEFT JOIN 
    TopUsers u ON u.TotalUpVotes = (SELECT MAX(TotalUpVotes) FROM TopUsers)
LEFT JOIN 
    TopTags t ON (SELECT COUNT(*) FROM TopTags) > 0
WHERE 
    ph.Level <= 3
ORDER BY 
    ph.Level, vs.UpVotes DESC, t.PostCount DESC;
