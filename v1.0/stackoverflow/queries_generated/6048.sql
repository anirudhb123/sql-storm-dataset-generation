WITH PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') as t ON t.TagName = (SELECT TagName FROM Tags WHERE Id = CAST(TRIM(BOTH '<>' FROM t) AS INT))
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
    HAVING 
        COUNT(a.Id) > 1 AND 
        p.Score > 10
), RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name IN ('Edit Body', 'Edit Title') AND 
        ph.CreationDate > NOW() - INTERVAL '30 days'
), UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.Tags,
    re.CreationDate AS LastEditDate,
    re.UserDisplayName AS EditedBy,
    uv.VoteCount,
    uv.UpVotes,
    uv.DownVotes
FROM 
    PopularPosts pp
LEFT JOIN 
    RecentEdits re ON pp.Id = re.PostId
LEFT JOIN 
    UserVotes uv ON pp.Id = uv.PostId
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
