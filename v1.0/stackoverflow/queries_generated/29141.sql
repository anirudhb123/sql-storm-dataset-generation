WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS Author,
        array_agg(DISTINCT c.Text) AS Comments
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.UpVotes,
    tt.DownVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Author,
    rp.Comments
FROM 
    TopTags tt
LEFT JOIN 
    RecentPosts rp ON rp.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.Tags ILIKE '%' || tt.TagName || '%'
    )
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.PostCount DESC, rp.CreationDate DESC;
