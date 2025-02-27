WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (10, 12) THEN 1 END) AS PostActions
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ARRAY(SELECT TRIM(unnest(string_to_array(p.Tags, '>'))) ) AS Tags,
        COUNT(c.Id) AS CommentCount,
        AVG(p.ViewCount) OVER() AS AvgViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    pws.PostId,
    pws.Title,
    pws.CreationDate,
    pws.Tags,
    pws.CommentCount,
    COALESCE(pu.UpVotes, 0) AS UpVotesUser,
    COALESCE(pu.DownVotes, 0) AS DownVotesUser,
    pws.AvgViewCount,
    phs.FirstEditDate,
    phs.LastEditDate,
    phs.EditCount
FROM 
    PostsWithTags pws
LEFT JOIN 
    UserVoteSummary pu ON pws.PostId = (SELECT pi.Id FROM Posts pi WHERE pi.OwnerUserId = pu.UserId ORDER BY pi.CreationDate DESC LIMIT 1)
LEFT JOIN 
    PostHistorySummary phs ON pws.PostId = phs.PostId
WHERE 
    pws.CommentCount > 0 
    AND EXISTS (SELECT 1 FROM Tags t WHERE t.WikiPostId = pws.PostId AND t.Count > 0)
    AND (phs.EditCount IS NULL OR phs.EditCount > 2)
ORDER BY 
    COALESCE(pws.CommentCount, 0) DESC, 
    pws.CreationDate DESC;
