
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
RecentPostEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        @rn := IF(@prev_id = p.Id, @rn + 1, 1) AS EditRank,
        @prev_id := p.Id
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    CROSS JOIN (SELECT @rn := 0, @prev_id := NULL) AS vars
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)
    ORDER BY 
        p.Id, ph.CreationDate DESC
), 
FrequentTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 20
)
SELECT 
    u.DisplayName,
    u.Reputation,
    uc.UpVotes,
    uc.DownVotes,
    rp.Title AS LastEditedTitle,
    rp.CreationDate AS LastEditDate,
    ft.TagName,
    ft.PostCount
FROM 
    Users u
LEFT JOIN 
    UserVoteCounts uc ON u.Id = uc.UserId
LEFT JOIN 
    RecentPostEdits rp ON u.DisplayName = rp.UserDisplayName 
    AND rp.EditRank = 1
LEFT JOIN 
    FrequentTags ft ON ft.PostCount > 20
WHERE 
    u.Reputation IS NOT NULL
    AND u.Location IS NOT NULL
    AND (uc.TotalVotes IS NULL OR uc.TotalVotes > 10)
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;
