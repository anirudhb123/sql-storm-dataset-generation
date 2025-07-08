
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, p.PostTypeId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Author,
        rp.RankScore,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.RankScore <= 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN LATERAL FLATTEN(input => SPLIT(p.Tags, '<>')) AS t ON TRUE
    GROUP BY p.Id
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Score,
    hsp.ViewCount,
    hsp.AnswerCount,
    hsp.Author,
    hsp.CommentCount,
    pt.Tags
FROM HighScoringPosts hsp
JOIN PostTags pt ON hsp.PostId = pt.PostId
ORDER BY hsp.Score DESC, hsp.ViewCount DESC;
