WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON u.Reputation > 1000 AND u.CreationDate < ur.CreationDate
),
PostVoteCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate > now() - interval '1 year'
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.AnswerCount,
        p.ViewCount,
        p.Score,
        ph.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11) -- Edit Title, Edit Body, Post Closed, Post Reopened
)
SELECT 
    u.DisplayName,
    ur.Level,
    phd.Title,
    phd.AnswerCount,
    phd.ViewCount,
    phd.Score,
    pc.TotalVotes,
    pc.UpVotes,
    pc.DownVotes,
    CASE 
        WHEN phd.EditComment IS NOT NULL THEN 'Edited'
        ELSE 'Unedited'
    END AS CommentStatus,
    AVG(u.Reputation) OVER () AS AverageReputation,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM 
    UserReputationCTE ur
JOIN 
    Users u ON ur.Id = u.Id
JOIN 
    PostHistoryDetails phd ON u.Id = phd.PostId
JOIN 
    PostVoteCount pc ON phd.PostId = pc.PostId
LEFT JOIN 
    PostTypes pt ON EXISTS (
        SELECT 1 FROM Posts p WHERE p.Id = phd.PostId AND p.PostTypeId = pt.Id
    )
WHERE 
    ur.Level < 3
ORDER BY 
    ur.Reputation DESC,
    phd.ViewCount DESC
LIMIT 100;
