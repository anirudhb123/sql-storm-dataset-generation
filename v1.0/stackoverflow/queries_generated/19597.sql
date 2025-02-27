SELECT U.DisplayName, P.Title, P.CreationDate, P.Score
FROM Users U
JOIN Posts P ON U.Id = P.OwnerUserId
WHERE P.PostTypeId = 1 -- Only questions
ORDER BY P.CreationDate DESC
LIMIT 10;
