
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        Users u, (SELECT @row_number := 0) r
    ORDER BY 
        u.Reputation DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, pt.Name, u.DisplayName
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(CONCAT(pt.Name, ' by ', ph.UserDisplayName) SEPARATOR ', ') AS History,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),
FinalData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostType,
        rp.OwnerDisplayName,
        rp.CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        ph.History,
        ph.LastModified,
        ru.DisplayName AS TopUser,
        ru.UserRank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        VoteSummary vs ON rp.PostId = vs.PostId
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    CROSS JOIN 
        (SELECT * FROM RankedUsers WHERE UserRank = 1) ru
)
SELECT 
    *
FROM 
    FinalData
WHERE 
    (UpVotes - DownVotes) > 10
    OR (CommentCount > 5 AND LastModified > (NOW() - INTERVAL 7 DAY))
ORDER BY 
    CreationDate DESC;
