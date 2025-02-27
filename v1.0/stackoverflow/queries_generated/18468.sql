SELECT U.DisplayName, P.Title, P.CreationDate
FROM Users AS U
JOIN Posts AS P ON U.Id = P.OwnerUserId
WHERE P.PostTypeId = 1  -- Filtering for questions
ORDER BY P.CreationDate DESC
LIMIT 10;
