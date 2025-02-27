WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ts.TagList,
        ROW_NUMBER() OVER (PARTITION BY ts.TagList ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    CROSS APPLY (
        SELECT STRING_AGG(t.TagName, ', ') AS TagList
        FROM Tags t
        WHERE t.Id IN (
            SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int) 
        )
    ) ts
    WHERE p.PostTypeId = 1  -- Only Questions
      AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        v.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.TagList,
        rp.Score,
        rp.AnswerCount,
        rp.ViewCount,
        rv.VoteCount,
        rv.UpVotes,
        rv.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.TagList,
    pm.Score,
    pm.AnswerCount,
    pm.ViewCount,
    COALESCE(pm.VoteCount, 0) AS VoteCount,
    COALESCE(pm.UpVotes, 0) AS UpVotes,
    COALESCE(pm.DownVotes, 0) AS DownVotes
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 5  -- Getting top 5 by score per tag
ORDER BY 
    pm.TagList, pm.Score DESC;
