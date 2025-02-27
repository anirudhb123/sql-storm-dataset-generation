WITH PostWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) 
            ELSE 0 
        END AS AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
        LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3)
        LEFT JOIN LATERAL (
            SELECT 
                UNNEST(string_to_array(p.Tags, '><')) AS TagName
        ) t ON true
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS ActionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.OwnerUserId = u.Id THEN v.UpVotes END), 0) AS TotalGivenVotes,
        COALESCE(SUM(CASE WHEN c.UserId = u.Id THEN 1 END), 0) AS TotalComments
    FROM 
        Users u
        LEFT JOIN Posts p ON p.OwnerUserId = u.Id
        LEFT JOIN Votes v ON v.UserId = u.Id
        LEFT JOIN Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    pwd.PostId,
    pwd.Title,
    pwd.CreationDate,
    pwd.ViewCount,
    pwd.UpVotes,
    pwd.DownVotes,
    ph.CloseCount,
    ph.ReopenCount,
    ph.DeleteCount,
    ue.UserId,
    ue.TotalGivenVotes,
    ue.TotalComments,
    CASE 
        WHEN pwd.AnswerCount = 0 THEN 'No Answers'
        WHEN pwd.AnswerCount < 3 THEN 'Few Answers'
        ELSE 'Many Answers'
    END AS AnswerFeedback
FROM 
    PostWithDetails pwd
    LEFT JOIN PostHistoryCTE ph ON ph.PostId = pwd.PostId
    LEFT JOIN UserEngagement ue ON TRUE
WHERE 
    (pwd.ViewCount - COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = pwd.PostId), 0)) > 10
    AND (ph.ActionCount > 1 OR pwd.UpVotes - pwd.DownVotes > 5)
ORDER BY 
    pwd.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
