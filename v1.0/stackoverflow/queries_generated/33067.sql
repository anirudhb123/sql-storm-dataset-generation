WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Focus on close and open actions

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE 
        ph.CreationDate < rph.CreationDate -- Recursive backtracking of post history
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 answers
),

ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS SourceHistoryLevel
    FROM 
        Posts p
    JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only considering posts that have been closed
),

TopClosedPosts AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.CreationDate,
        cp.UserDisplayName,
        COUNT(*) OVER (PARTITION BY cp.PostId) AS CloseCount
    FROM 
        ClosedPosts cp
    ORDER BY 
        CloseCount DESC
    LIMIT 10
)

SELECT 
    u.DisplayName AS TopUser,
    tc.Title AS ClosedPostTitle,
    tc.CreationDate AS ClosedPostDate,
    tc.UserDisplayName AS CloserDisplayName,
    COUNT(DISTINCT u.Id) AS NumberOfTopUsers,
    COALESCE(up.UpVotes, 0) AS TotalUpVotes,
    COALESCE(dn.DownVotes, 0) AS TotalDownVotes,
    tn.AnswerCount AS UserAnswerCount
FROM 
    TopClosedPosts tc
JOIN 
    Users u ON u.Id IN (SELECT DISTINCT ph.UserId FROM RecursivePostHistory ph WHERE ph.PostId = tc.PostId)
LEFT JOIN 
    TopUsers up ON u.Id = up.Id
LEFT JOIN 
    TopUsers dn ON u.Id = dn.Id
GROUP BY 
    u.DisplayName, tc.Title, tc.CreationDate, tc.UserDisplayName, up.UpVotes, dn.DownVotes, tn.AnswerCount
ORDER BY 
    TotalUpVotes DESC,
    ClosedPostDate DESC;
