WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Starting with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        rp.Level + 1
    FROM Posts p
    JOIN RecursivePostCTE rp ON p.ParentId = rp.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY p.Id
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS ActivePostCount
    FROM Users u 
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY u.Id
),
TagsWithPostCount AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)

SELECT 
    rp.Title AS QuestionTitle,
    rp.Level AS QuestionLevel,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    re.LastEditDate,
    re.EditCount,
    au.DisplayName AS ActiveUserName,
    au.ActivePostCount,
    tw.TagName,
    tw.PostCount
FROM RecursivePostCTE rp
LEFT JOIN PostVoteSummary ps ON rp.Id = ps.PostId
LEFT JOIN RecentEdits re ON rp.Id = re.PostId
LEFT JOIN ActiveUsers au ON rp.OwnerUserId = au.UserId
LEFT JOIN TagsWithPostCount tw ON tw.PostCount > 0
WHERE rp.CreationDate >= NOW() - INTERVAL '6 months'
AND (ps.UpVotes - ps.DownVotes) > 0
ORDER BY rp.Level, ps.VoteCount DESC, re.LastEditDate DESC;
