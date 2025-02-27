-- Performance benchmarking SQL query to analyze the average score of questions based on user reputation and the number of tags

SELECT 
    AVG(p.Score) AS AverageQuestionScore,
    u.Reputation AS UserReputation,
    COUNT(DISTINCT t.Id) AS TagCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int[])
WHERE 
    p.PostTypeId = 1  -- Only consider questions
GROUP BY 
    u.Reputation
ORDER BY 
    UserReputation DESC;
