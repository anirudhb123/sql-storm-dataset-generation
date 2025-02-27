WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopQuestions AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.CommentCount,
    tq.UpVotes,
    tq.DownVotes,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    COALESCE(tg.TagCount, 0) AS TagCount,
    COALESCE(tg.TagsList, '') AS Tags
FROM 
    TopQuestions tq
JOIN 
    Users u ON tq.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        p.Id AS PostId, 
        COUNT(t.Id) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        STRING_SPLIT(p.Tags, ',') AS tagHelper ON tagHelper.value IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(tagHelper.value)
    GROUP BY 
        p.Id
) tg ON tq.PostId = tg.PostId
ORDER BY 
    tq.Score DESC;
