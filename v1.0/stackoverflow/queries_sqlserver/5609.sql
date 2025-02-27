
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(p.Tags, '><')) AS t
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, t.TagName
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (PARTITION BY pd.TagName ORDER BY pd.Score DESC, pd.ViewCount DESC) AS TagRank
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.TagName
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank <= 5
ORDER BY 
    rp.TagName, rp.TagRank;
