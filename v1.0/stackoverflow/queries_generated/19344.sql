SELECT
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes
FROM
    Users u
LEFT JOIN
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    u.DisplayName
ORDER BY
    PostCount DESC
LIMIT 10;
