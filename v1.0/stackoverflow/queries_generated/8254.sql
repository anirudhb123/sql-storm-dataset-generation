WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Views,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Views, p.Score, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Posts sub_p WHERE sub_p.ParentId = rp.PostId) AS AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5 AND rp.Views > 100
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Views,
    fp.Score,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(fp.Tags, '<>')) AS TagName
    ) t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Views, fp.Score, 
    fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount, 
    fp.AnswerCount, fp.OwnerDisplayName
ORDER BY 
    fp.Score DESC, fp.Views DESC;
