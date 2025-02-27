WITH RecursiveCTE AS (
    -- Step 1: Identify the top 5 most active users based on posts created
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
VoteStats AS (
    -- Step 2: Gather vote statistics for each post by the top active users
    SELECT 
        p.Id AS PostId,
        u.DisplayName AS UserName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Id IN (SELECT UserId FROM RecursiveCTE)
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    -- Step 3: Fetch post history for each post, along with the last edit date
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
FinalStats AS (
    -- Step 4: Combine votes and post history information
    SELECT 
        vs.PostId,
        vs.UserName,
        vs.VoteCount,
        vs.UpVotes,
        vs.DownVotes,
        ph.LastEdited,
        ph.EditComments
    FROM 
        VoteStats vs
    JOIN 
        PostHistoryDetails ph ON vs.PostId = ph.PostId
)
-- Step 5: Final selection and order by votes received and edit date
SELECT 
    fs.UserName,
    fs.PostId,
    fs.VoteCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.LastEdited,
    fs.EditComments
FROM 
    FinalStats fs
ORDER BY 
    fs.VoteCount DESC,
    fs.LastEdited DESC;

