
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) as Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND 
          p.Score > 0 AND 
          p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TagSummary AS (
    SELECT 
        LOWER(LTRIM(RTRIM(value))) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') AS value
    WHERE p.PostTypeId = 1
    GROUP BY LOWER(LTRIM(RTRIM(value)))
),
PopularTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM TagSummary ts
    WHERE ts.PostCount > 10
),
PostInteraction AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    pt.TagName AS RelatedTag
FROM RankedPosts rp
JOIN PostInteraction pi ON rp.PostId = pi.PostId
LEFT JOIN PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '>'))
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, pi.UpVoteCount DESC;
