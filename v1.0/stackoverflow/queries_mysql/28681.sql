
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS RankByAnswers
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
), 
FilteredPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE RankByAnswers <= 50 
), 
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM FilteredPosts
    JOIN (
        SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
     ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
), 
TagRanking AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM TopTags
    GROUP BY Tag
    ORDER BY TagCount DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Owner,
    fp.CreationDate,
    fp.AnswerCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    tr.Tag,
    tr.TagCount
FROM FilteredPosts fp
JOIN TagRanking tr ON tr.Tag IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '><', n.n), '><', -1)
                                   FROM (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                                         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n)
ORDER BY fp.AnswerCount DESC, tr.TagCount DESC;
