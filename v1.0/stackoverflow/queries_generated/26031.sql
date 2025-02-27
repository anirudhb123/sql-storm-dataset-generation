WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS EditorsCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, or Tags edited
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Tags,
    COALESCE(pha.EditCount, 0) AS EditCount,
    COALESCE(pha.EditorsCount, 0) AS EditorsCount,
    COALESCE(pha.LastEditDate, 'Never') AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
ORDER BY 
    rp.Score DESC, 
    rp.CommentCount DESC;
