WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosedAndEdited AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosedCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
UserTags AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName)
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ps.PostCount,
        CASE 
            WHEN postTags.Tags IS NOT NULL THEN postTags.Tags
            ELSE 'No Tags' 
        END AS Tags,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open' 
        END AS State
    FROM 
        Posts p
    LEFT JOIN 
        UserVoteStats ps ON ps.UserId = p.OwnerUserId
    LEFT JOIN 
        UserTags postTags ON postTags.UserId = p.OwnerUserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCount,
    ps.Tags,
    ps.State,
    CASE 
        WHEN ps.State = 'Closed' THEN COALESCE(PCS.ClosedCount, 0)
        ELSE NULL 
    END AS TotalCloseVotes,
    ROW_NUMBER() OVER (PARTITION BY ps.State ORDER BY ps.PostCount DESC) AS Ranking
FROM 
    PostStats ps
LEFT JOIN 
    PostClosedAndEdited PCS ON ps.PostId = PCS.PostId
WHERE 
    (ps.State = 'Closed' OR ps.PostCount > 0)
ORDER BY 
    Ranking, ps.Title;
