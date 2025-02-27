WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 3
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount 
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName 
    HAVING 
        COUNT(p.Id) > 10
),
PostWithTags AS (
    SELECT 
        trp.PostId, 
        trp.Title, 
        trp.CreationDate, 
        trp.Score, 
        pt.TagName 
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Tags pt ON trp.Title LIKE '%' || pt.TagName || '%'
)
SELECT 
    pw.PostId, 
    pw.Title, 
    pw.CreationDate, 
    pw.Score, 
    COALESCE(pt.TagName, 'No Tag') AS TagName,
    (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL) AS AvgPostScore,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pw.PostId AND v.VoteTypeId = 2) AS UpVotes
FROM 
    PostWithTags pw
FULL OUTER JOIN 
    PopularTags pt ON pt.TagName = COALESCE(SUBSTRING(pw.Title FROM '^(.*?)(:|;|$)'), 'No Tag')
WHERE 
    pw.Score > (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL)
ORDER BY 
    pw.Score DESC, pw.CreationDate DESC;
