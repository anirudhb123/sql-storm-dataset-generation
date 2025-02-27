WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(ph.LastEditDate, p.CreationDate) AS LastEditOrCreationDate,
        COALESCE(h.UserId, -1) AS LastEditedByUserId,
        h.UserDisplayName AS LastEditedByUserName,
        p.AcceptedAnswerId,
        ps.RevisionGUID,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(ph.LastEditDate, p.CreationDate) DESC) AS EditRank
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags Edited
    LEFT JOIN PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId IN (4, 5, 7) -- Last Editor User
    LEFT JOIN PostHistory ps ON p.Id = ps.PostId AND ps.PostHistoryTypeId = 24 -- Suggested Edit Applied
),

AggregatedPostData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.LastEditOrCreationDate,
        pd.LastEditedByUserId,
        pd.LastEditedByUserName,
        pd.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM PostDetail pd
    LEFT JOIN Comments c ON pd.PostId = c.PostId 
    LEFT JOIN Votes v ON pd.PostId = v.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.ViewCount, 
        pd.LastEditOrCreationDate, pd.LastEditedByUserId, 
        pd.LastEditedByUserName, pd.AcceptedAnswerId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    aps.PostId,
    aps.Title,
    aps.ViewCount,
    aps.LastEditOrCreationDate,
    aps.LastEditedByUserId,
    aps.LastEditedByUserName,
    aps.CommentCount,
    aps.TotalUpVotes,
    aps.TotalDownVotes,
    uvs.TotalVotes,
    CASE WHEN aps.AcceptedAnswerId IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsAccepted
FROM UserVoteSummary uvs
JOIN AggregatedPostData aps ON uvs.UserId = aps.LastEditedByUserId
LEFT JOIN Users ups ON ups.Id = aps.LastEditedByUserId
WHERE aps.TotalUpVotes - aps.TotalDownVotes > 0 -- Ensure net upvotes
ORDER BY aps.ViewCount DESC, aps.TotalUpVotes DESC;
