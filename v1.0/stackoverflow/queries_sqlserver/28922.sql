
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COALESCE(DATALENGTH(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2)) - DATALENGTH(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', '')) + 1, 0) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentVotes AS (
    SELECT 
        v.PostId AS QuestionId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND
        v.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') 
    GROUP BY 
        v.PostId
),
TopQuestions AS (
    SELECT 
        pt.PostId,
        pt.Title,
        pt.TagCount,
        rv.UpVotes,
        rv.DownVotes,
        pt.Tags
    FROM 
        PostTagCounts pt
    LEFT JOIN 
        RecentVotes rv ON pt.PostId = rv.QuestionId
    ORDER BY 
        pt.TagCount DESC, 
        rv.UpVotes - rv.DownVotes DESC 
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.TagCount,
    COALESCE(tq.UpVotes, 0) AS UpVotes,
    COALESCE(tq.DownVotes, 0) AS DownVotes,
    tq.Tags,
    u.Reputation,
    u.DisplayName
FROM 
    TopQuestions tq
JOIN 
    Posts p ON tq.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
ORDER BY 
    tq.TagCount DESC, 
    tq.UpVotes - tq.DownVotes DESC;
