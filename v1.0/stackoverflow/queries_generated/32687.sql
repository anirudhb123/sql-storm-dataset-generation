WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryCreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Only considering close/open/delete actions
),

LatestVote AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId, v.VoteTypeId
),

EngagedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate AS PostCreationDate,
    ph.HistoryCreationDate,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS TotalComments,
    eu.UserId AS EngagedUserId,
    eu.DisplayName AS EngagedUserName,
    eu.UpVotes,
    eu.DownVotes,
    eu.CommentCount
FROM 
    RecursivePostHistory ph
LEFT JOIN 
    LatestVote v ON ph.PostId = v.PostId
LEFT JOIN 
    EngagedUsers eu ON ph.PostId IN (
        SELECT DISTINCT PostId FROM Votes WHERE UserId = eu.UserId
    )
WHERE 
    ph.HistoryRank = 1 -- Select the latest history entry
ORDER BY 
    ph.HistoryCreationDate DESC, TotalVotes DESC;
